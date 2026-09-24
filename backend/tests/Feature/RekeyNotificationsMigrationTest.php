<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Notifications\DatabaseNotification;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Tests\TestCase;

/**
 * The rekey migration is a hand-copied package stub that drops and rebuilds a
 * table, so this app keeps its own proof that the copy still does that. Under
 * RefreshDatabase the create migration already builds a UUID table, so the
 * test puts back the integer-keyed shape an earlier migrate left behind.
 */
class RekeyNotificationsMigrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_rebuilds_an_integer_keyed_table_and_keeps_its_rows(): void
    {
        // 1. The table this app built before its notifications id became a UUID.
        $user = User::factory()->create();
        Schema::drop('notifications');
        Schema::create('notifications', function (Blueprint $table): void {
            $table->id();
            $table->string('type');
            $table->morphs('notifiable');
            $table->text('data');
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            $table->index([
                'notifiable_type',
                'notifiable_id',
                'read_at',
            ]);
        });
        DB::table('notifications')->insert([
            'id' => 7,
            'type' => DatabaseOnlyNotification::class,
            'notifiable_type' => $user->getMorphClass(),
            'notifiable_id' => $user->getKey(),
            'data' => json_encode([
                'title' => 'Carried over',
            ]),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $migration = require database_path('migrations/2026_09_24_000020_rekey_notifications_table_by_uuid.php');
        $migration->up();

        // 2. The row survived under a UUID, and both lookup indexes are back.
        $carried = DatabaseNotification::query()->sole();
        $this->assertTrue(Str::isUuid($carried->id));
        $this->assertSame('Carried over', $carried->data['title']);
        $this->assertTrue(Schema::hasIndex('notifications', 'notifications_notifiable_type_notifiable_id_index'));
        $this->assertTrue(
            Schema::hasIndex('notifications', 'notifications_notifiable_type_notifiable_id_read_at_index'),
        );

        // 3. The database channel can write to it again.
        $sent = new DatabaseOnlyNotification;
        $sent->id = (string) Str::uuid();
        $user->notify($sent);
        $this->assertTrue(DatabaseNotification::query()->whereKey($sent->id)->exists());
    }

    public function test_the_users_table_carries_the_column_onesignal_sms_registration_writes(): void
    {
        $this->assertTrue(Schema::hasColumn('users', 'sms_registered_at'));
    }
}
